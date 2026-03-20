using System.Text.Json;
using FamilyRecipeBook.Web.Models;

namespace FamilyRecipeBook.Web.Data;

public sealed class FileRecipeRepository : IRecipeRepository
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = true
    };

    private readonly string _storePath;
    private readonly SemaphoreSlim _lock = new(1, 1);

    public FileRecipeRepository(IWebHostEnvironment environment)
    {
        var dataDirectory = Path.Combine(environment.ContentRootPath, "App_Data");
        Directory.CreateDirectory(dataDirectory);
        _storePath = Path.Combine(dataDirectory, "recipes.json");
    }

    public async Task<IReadOnlyList<RecipeListItem>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        await _lock.WaitAsync(cancellationToken);
        try
        {
            var store = await ReadStoreAsync(cancellationToken);
            return store.Recipes
                .OrderBy(r => r.Title, StringComparer.OrdinalIgnoreCase)
                .Select(r => new RecipeListItem
                {
                    RecipeId = r.RecipeId,
                    Title = r.Title,
                    Description = r.Description,
                    PrepMinutes = r.PrepMinutes,
                    CookMinutes = r.CookMinutes,
                    Servings = r.Servings,
                    IsFavorite = r.IsFavorite
                })
                .ToList();
        }
        finally
        {
            _lock.Release();
        }
    }

    public async Task<RecipeDetailViewModel?> GetByIdAsync(int recipeId, CancellationToken cancellationToken = default)
    {
        await _lock.WaitAsync(cancellationToken);
        try
        {
            var store = await ReadStoreAsync(cancellationToken);
            var recipe = store.Recipes.FirstOrDefault(r => r.RecipeId == recipeId);
            if (recipe is null)
            {
                return null;
            }

            return new RecipeDetailViewModel
            {
                RecipeId = recipe.RecipeId,
                Title = recipe.Title,
                Description = recipe.Description,
                PrepMinutes = recipe.PrepMinutes,
                CookMinutes = recipe.CookMinutes,
                Servings = recipe.Servings,
                Source = recipe.Source,
                IsFavorite = recipe.IsFavorite,
                SubmittedBy = recipe.SubmittedBy,
                Categories = recipe.Categories,
                Ingredients = recipe.Ingredients
                    .OrderBy(i => i.SequenceNumber)
                    .Select(i => new IngredientLine
                    {
                        SequenceNumber = i.SequenceNumber,
                        IngredientName = i.IngredientName,
                        Quantity = i.Quantity,
                        Unit = i.Unit,
                        PrepNote = i.PrepNote
                    })
                    .ToList(),
                Steps = recipe.Steps
                    .OrderBy(s => s.StepNumber)
                    .Select(s => new RecipeStepLine
                    {
                        StepNumber = s.StepNumber,
                        InstructionText = s.InstructionText
                    })
                    .ToList()
            };
        }
        finally
        {
            _lock.Release();
        }
    }

    public async Task<int> CreateAsync(CreateRecipeInputModel model, CancellationToken cancellationToken = default)
    {
        await _lock.WaitAsync(cancellationToken);
        try
        {
            var store = await ReadStoreAsync(cancellationToken);
            var nextId = store.Recipes.Count == 0 ? 1 : store.Recipes.Max(r => r.RecipeId) + 1;

            var ingredients = model.Ingredients
                .Where(i => !string.IsNullOrWhiteSpace(i.IngredientName))
                .Select((i, idx) => new StoredIngredient
                {
                    SequenceNumber = idx + 1,
                    IngredientName = i.IngredientName.Trim(),
                    Quantity = i.Quantity,
                    Unit = string.IsNullOrWhiteSpace(i.Unit) ? null : i.Unit.Trim(),
                    PrepNote = string.IsNullOrWhiteSpace(i.PrepNote) ? null : i.PrepNote.Trim()
                })
                .ToList();

            var steps = model.Steps
                .Where(s => !string.IsNullOrWhiteSpace(s.InstructionText))
                .Select((s, idx) => new StoredStep
                {
                    StepNumber = idx + 1,
                    InstructionText = s.InstructionText.Trim()
                })
                .ToList();

            store.Recipes.Add(new StoredRecipe
            {
                RecipeId = nextId,
                Title = model.Title,
                Description = model.Description,
                PrepMinutes = model.PrepMinutes,
                CookMinutes = model.CookMinutes,
                Servings = model.Servings,
                Source = model.Source,
                IsFavorite = model.IsFavorite,
                SubmittedBy = string.IsNullOrWhiteSpace(model.SubmittedBy) ? null : model.SubmittedBy.Trim(),
                Categories = [],
                Ingredients = ingredients,
                Steps = steps
            });

            await WriteStoreAsync(store, cancellationToken);
            return nextId;
        }
        finally
        {
            _lock.Release();
        }
    }

    public async Task UpdateAsync(int recipeId, CreateRecipeInputModel model, CancellationToken cancellationToken = default)
    {
        await _lock.WaitAsync(cancellationToken);
        try
        {
            var store = await ReadStoreAsync(cancellationToken);
            var recipe = store.Recipes.FirstOrDefault(r => r.RecipeId == recipeId);
            if (recipe is null)
            {
                return;
            }

            recipe.Title = model.Title;
            recipe.Description = model.Description;
            recipe.PrepMinutes = model.PrepMinutes;
            recipe.CookMinutes = model.CookMinutes;
            recipe.Servings = model.Servings;
            recipe.Source = model.Source;
            recipe.IsFavorite = model.IsFavorite;
            recipe.SubmittedBy = string.IsNullOrWhiteSpace(model.SubmittedBy) ? null : model.SubmittedBy.Trim();

            recipe.Ingredients = model.Ingredients
                .Where(i => !string.IsNullOrWhiteSpace(i.IngredientName))
                .Select((i, idx) => new StoredIngredient
                {
                    SequenceNumber = idx + 1,
                    IngredientName = i.IngredientName.Trim(),
                    Quantity = i.Quantity,
                    Unit = string.IsNullOrWhiteSpace(i.Unit) ? null : i.Unit.Trim(),
                    PrepNote = string.IsNullOrWhiteSpace(i.PrepNote) ? null : i.PrepNote.Trim()
                })
                .ToList();

            recipe.Steps = model.Steps
                .Where(s => !string.IsNullOrWhiteSpace(s.InstructionText))
                .Select((s, idx) => new StoredStep
                {
                    StepNumber = idx + 1,
                    InstructionText = s.InstructionText.Trim()
                })
                .ToList();

            await WriteStoreAsync(store, cancellationToken);
        }
        finally
        {
            _lock.Release();
        }
    }

    public async Task DeleteAsync(int recipeId, CancellationToken cancellationToken = default)
    {
        await _lock.WaitAsync(cancellationToken);
        try
        {
            var store = await ReadStoreAsync(cancellationToken);
            var removed = store.Recipes.RemoveAll(r => r.RecipeId == recipeId);
            if (removed > 0)
            {
                await WriteStoreAsync(store, cancellationToken);
            }
        }
        finally
        {
            _lock.Release();
        }
    }

    private async Task<RecipeStore> ReadStoreAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(_storePath))
        {
            var seeded = SeedStore();
            await WriteStoreAsync(seeded, cancellationToken);
            return seeded;
        }

        await using var stream = File.OpenRead(_storePath);
        var store = await JsonSerializer.DeserializeAsync<RecipeStore>(stream, JsonOptions, cancellationToken);
        return store ?? new RecipeStore();
    }

    private async Task WriteStoreAsync(RecipeStore store, CancellationToken cancellationToken)
    {
        await using var stream = File.Create(_storePath);
        await JsonSerializer.SerializeAsync(stream, store, JsonOptions, cancellationToken);
    }

    private static RecipeStore SeedStore()
    {
        return new RecipeStore
        {
            Recipes =
            [
                new StoredRecipe
                {
                    RecipeId = 1,
                    Title = "Grandma's Pancakes",
                    Description = "Fluffy Sunday pancakes from the handwritten family card.",
                    PrepMinutes = 10,
                    CookMinutes = 15,
                    Servings = 4,
                    Source = "Family Card Box",
                    IsFavorite = true,
                    SubmittedBy = "Grandma Rose",
                    Categories = ["Breakfast"],
                    Ingredients =
                    [
                        new StoredIngredient { SequenceNumber = 1, IngredientName = "Flour", Quantity = 2.00m, Unit = "cups" },
                        new StoredIngredient { SequenceNumber = 2, IngredientName = "Sugar", Quantity = 2.00m, Unit = "tbsp" },
                        new StoredIngredient { SequenceNumber = 3, IngredientName = "Baking Powder", Quantity = 1.00m, Unit = "tbsp" },
                        new StoredIngredient { SequenceNumber = 4, IngredientName = "Salt", Quantity = 0.50m, Unit = "tsp" },
                        new StoredIngredient { SequenceNumber = 5, IngredientName = "Milk", Quantity = 1.50m, Unit = "cups" },
                        new StoredIngredient { SequenceNumber = 6, IngredientName = "Eggs", Quantity = 1.00m, Unit = "large", PrepNote = "beaten" },
                        new StoredIngredient { SequenceNumber = 7, IngredientName = "Butter", Quantity = 3.00m, Unit = "tbsp", PrepNote = "melted" },
                        new StoredIngredient { SequenceNumber = 8, IngredientName = "Vanilla Extract", Quantity = 1.00m, Unit = "tsp" }
                    ],
                    Steps =
                    [
                        new StoredStep { StepNumber = 1, InstructionText = "Whisk dry ingredients in a large bowl." },
                        new StoredStep { StepNumber = 2, InstructionText = "Stir in milk, egg, melted butter, and vanilla until just combined." },
                        new StoredStep { StepNumber = 3, InstructionText = "Heat a lightly buttered skillet over medium heat." },
                        new StoredStep { StepNumber = 4, InstructionText = "Pour 1/4 cup batter per pancake and cook until bubbles form." },
                        new StoredStep { StepNumber = 5, InstructionText = "Flip and cook until golden brown." },
                        new StoredStep { StepNumber = 6, InstructionText = "Serve warm with syrup or fruit." }
                    ]
                }
            ]
        };
    }

    private sealed class RecipeStore
    {
        public List<StoredRecipe> Recipes { get; set; } = [];
    }

    private sealed class StoredRecipe
    {
        public int RecipeId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int PrepMinutes { get; set; }
        public int CookMinutes { get; set; }
        public int? Servings { get; set; }
        public string? Source { get; set; }
        public bool IsFavorite { get; set; }
        public string? SubmittedBy { get; set; }
        public List<string> Categories { get; set; } = [];
        public List<StoredIngredient> Ingredients { get; set; } = [];
        public List<StoredStep> Steps { get; set; } = [];
    }

    private sealed class StoredIngredient
    {
        public int SequenceNumber { get; set; }
        public string IngredientName { get; set; } = string.Empty;
        public decimal? Quantity { get; set; }
        public string? Unit { get; set; }
        public string? PrepNote { get; set; }
    }

    private sealed class StoredStep
    {
        public int StepNumber { get; set; }
        public string InstructionText { get; set; } = string.Empty;
    }
}
