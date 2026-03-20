using System.ComponentModel.DataAnnotations;

namespace FamilyRecipeBook.Web.Models;

public sealed class CreateRecipeInputModel
{
    [Required]
    [StringLength(200)]
    public string Title { get; set; } = string.Empty;

    [StringLength(1000)]
    public string? Description { get; set; }

    [Range(0, 1440)]
    public int PrepMinutes { get; set; }

    [Range(0, 1440)]
    public int CookMinutes { get; set; }

    [Range(1, 200)]
    public int? Servings { get; set; }

    [StringLength(300)]
    public string? Source { get; set; }

    public bool IsFavorite { get; set; }

    [StringLength(100)]
    [Display(Name = "Submitted By")]
    public string? SubmittedBy { get; set; }

    public List<IngredientInputLine> Ingredients { get; set; } = [];

    public List<StepInputLine> Steps { get; set; } = [];
}

public sealed class IngredientInputLine
{
    [StringLength(150)]
    [Display(Name = "Ingredient")]
    public string IngredientName { get; set; } = string.Empty;

    public decimal? Quantity { get; set; }

    [StringLength(50)]
    public string? Unit { get; set; }

    [StringLength(200)]
    [Display(Name = "Prep Note")]
    public string? PrepNote { get; set; }
}

public sealed class StepInputLine
{
    [StringLength(2000)]
    [Display(Name = "Step")]
    public string InstructionText { get; set; } = string.Empty;
}
