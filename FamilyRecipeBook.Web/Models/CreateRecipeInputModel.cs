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

    [Range(1, int.MaxValue)]
    public int? CreatedByMemberId { get; set; }
}
