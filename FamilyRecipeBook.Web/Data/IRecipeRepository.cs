using FamilyRecipeBook.Web.Models;

namespace FamilyRecipeBook.Web.Data;

public interface IRecipeRepository
{
    Task<IReadOnlyList<RecipeListItem>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<RecipeDetailViewModel?> GetByIdAsync(int recipeId, CancellationToken cancellationToken = default);
    Task<int> CreateAsync(CreateRecipeInputModel model, CancellationToken cancellationToken = default);
    Task<bool> UpdateAsync(int recipeId, CreateRecipeInputModel model, CancellationToken cancellationToken = default);
    Task DeleteAsync(int recipeId, CancellationToken cancellationToken = default);
}
