namespace FamilyRecipeBook.Web.Models;

public sealed class RecipeListItem
{
    public int RecipeId { get; init; }
    public string Title { get; init; } = string.Empty;
    public string? Description { get; init; }
    public int PrepMinutes { get; init; }
    public int CookMinutes { get; init; }
    public int TotalMinutes => PrepMinutes + CookMinutes;
    public int? Servings { get; init; }
    public bool IsFavorite { get; init; }
}
