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
            ViewData["ErrorMessage"] = "Unable to load recipes. Confirm your SQL Server is running and the RecipeBook connection string is correct.";
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
}
