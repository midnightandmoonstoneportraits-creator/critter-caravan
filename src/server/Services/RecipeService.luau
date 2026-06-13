local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Knit)
local RecipeData = require(ReplicatedStorage.Knit.Data.RecipeData)

local RecipeService = Knit.CreateService {
	Name = "RecipeService",
	Client = {
		RecipeUnlocked = Knit.CreateSignal(),
	},
}

function RecipeService:KnitStart()
	print("RecipeService started")
end

function RecipeService:CheckLevelUnlocks(player, level)
	for recipeId, data in pairs(RecipeData) do
		if data.UnlocksAtLevel and data.UnlocksAtLevel <= level then
			self:UnlockRecipe(player, recipeId)
		end
	end
end

function RecipeService:UnlockRecipe(player, recipeId)
	local FieldJournalService = Knit.GetService("FieldJournalService")
	FieldJournalService:RecordDiscovery(player, "Recipe", recipeId)
	
	-- Any other logic for recipe unlocking
end

function RecipeService.Client:GetRecipes(player)
	-- Return recipes player can see
	return RecipeData
end

return RecipeService
