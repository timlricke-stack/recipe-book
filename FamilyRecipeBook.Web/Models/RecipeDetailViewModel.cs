namespace FamilyRecipeBook.Web.Models;

public sealed class RecipeDetailViewModel
{
    public int RecipeId { get; init; }
    public string Title { get; init; } = string.Empty;
    public string? Description { get; init; }
    public int PrepMinutes { get; init; }
    public int CookMinutes { get; init; }
    public int TotalMinutes => PrepMinutes + CookMinutes;
    public int? Servings { get; init; }
    public string? Source { get; init; }
    public bool IsFavorite { get; init; }
    public string? SubmittedBy { get; init; }
    public IReadOnlyList<string> Categories { get; init; } = [];
    public IReadOnlyList<IngredientLine> Ingredients { get; init; } = [];
    public IReadOnlyList<RecipeStepLine> Steps { get; init; } = [];
}

public sealed class IngredientLine
{
    public int SequenceNumber { get; init; }
    public string IngredientName { get; init; } = string.Empty;
    public decimal? Quantity { get; init; }
    public string? Unit { get; init; }
    public string? PrepNote { get; init; }
}

public sealed class RecipeStepLine
{
    public int StepNumber { get; init; }
    public string InstructionText { get; init; } = string.Empty;
}
