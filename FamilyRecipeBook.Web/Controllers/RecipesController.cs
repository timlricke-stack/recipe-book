using FamilyRecipeBook.Web.Data;
using FamilyRecipeBook.Web.Models;
using Microsoft.AspNetCore.Mvc;

namespace FamilyRecipeBook.Web.Controllers;

public sealed class RecipesController : Controller
{
    private readonly IRecipeRepository _recipeRepository;
    private readonly ILogger<RecipesController> _logger;

    public RecipesController(IRecipeRepository recipeRepository, ILogger<RecipesController> logger)
    {
        _recipeRepository = recipeRepository;
        _logger = logger;
    }

    public async Task<IActionResult> Index(CancellationToken cancellationToken)
    {
        try
        {
            var recipes = await _recipeRepository.GetAllAsync(cancellationToken);
            return View(recipes);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load recipes.");
            ViewData["ErrorMessage"] = "Unable to load recipes. Please check your data storage configuration.";
            return View((IReadOnlyList<RecipeListItem>)new List<RecipeListItem>());
        }
    }

    public async Task<IActionResult> Details(int id, CancellationToken cancellationToken)
    {
        var recipe = await _recipeRepository.GetByIdAsync(id, cancellationToken);
        if (recipe is null)
        {
            return NotFound();
        }

        return View(recipe);
    }

    [HttpGet]
    public IActionResult Create()
    {
        return View(new CreateRecipeInputModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CreateRecipeInputModel model, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var id = await _recipeRepository.CreateAsync(model, cancellationToken);
        return RedirectToAction(nameof(Details), new { id });
    }

    [HttpGet]
    public async Task<IActionResult> Edit(int id, CancellationToken cancellationToken)
    {
        var recipe = await _recipeRepository.GetByIdAsync(id, cancellationToken);
        if (recipe is null)
        {
            return NotFound();
        }

        var model = new CreateRecipeInputModel
        {
            Title = recipe.Title,
            Description = recipe.Description,
            PrepMinutes = recipe.PrepMinutes,
            CookMinutes = recipe.CookMinutes,
            Servings = recipe.Servings,
            Source = recipe.Source,
            IsFavorite = recipe.IsFavorite,
            SubmittedBy = recipe.SubmittedBy,
            Ingredients = recipe.Ingredients
                .Select(i => new IngredientInputLine
                {
                    IngredientName = i.IngredientName,
                    Quantity = i.Quantity,
                    Unit = i.Unit,
                    PrepNote = i.PrepNote
                })
                .ToList(),
            Steps = recipe.Steps
                .Select(s => new StepInputLine
                {
                    InstructionText = s.InstructionText
                })
                .ToList()
        };

        ViewData["RecipeId"] = id;
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, CreateRecipeInputModel model, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            ViewData["RecipeId"] = id;
            return View(model);
        }

        await _recipeRepository.UpdateAsync(id, model, cancellationToken);
        return RedirectToAction(nameof(Details), new { id });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
    {
        await _recipeRepository.DeleteAsync(id, cancellationToken);
        return RedirectToAction(nameof(Index));
    }
}
