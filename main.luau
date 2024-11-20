-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Player Variables
local _Player: Player = Players.LocalPlayer
local _Character: Model?
local _Humanoid: Humanoid
local _Hrp: BasePart

-- Data Variables
local _DataEvent = ReplicatedStorage:WaitForChild("dataRemoteEvent")
local Remotes = ReplicatedStorage:WaitForChild("remotes")

-- Config
local Config = {
	GameSettings = {
		DoBonusBoss = true,
		ReturnOnInventoryLimit = 999,
		RetryDungeon = true,
		DisableDodging = false,
		Optimizations = {
			PerformanceMode = true,
			DestroyGear = true,
			FpsBoost = true,
		},
		BossSettings = {
			EnemyDistance = 50,
			CastingRange = 75,
			Teleports = {
				Enabled = true,
				Distance = 10,
				Delay = 0.2,
			},
		},
		MobSettings = {
			EnemyDistance = 30,
			CastingRange = 40,
			Teleports = {
				Enabled = true,
				Distance = 10,
				Delay = 0.2,
			},
		},
		Miscellaneous = {
			ShowTarget = true,
			ShowPath = true,
		},
	},
	LobbySettings = {
		CharacterSelection = 1, -- Accepted Values: 1, 2, 3, 4
		GameCreation = {
			MultiFarm = {
				Enabled = false,
				HostAccount = "",
				JoinerAccounts = { "Nigger", "Nigger2" },
			},
			DungeonSettings = {
				Dungeon = "Yokai Peak",
				Difficulty = "Nightmare",
				Hardcore = true,
				AutoSelectHighest = true,
			},
		},
		AutoEquip = {
			Enabled = true,
			Class = "physical",
		},
		AutoUpgrade = {
			Enabled = true,
		},
		AutoSkillPoints = {
			Enabled = true,
			Class = "physicalPower", -- Accepted Values: physical Power Or spellPower
			RequiredHealth = 100,
		},
		Miscellaneous = {
			CollectDailyReward = true,
			Yield = {
				WalkInLobby = {
					Enabled = true,
					ShowPath = true,
					Time = 30,
				},
			},
		},
		AutoSell = {
			Enabled = true,
			TestSell = false,
			ItemLevelRequirement = 216,
			Keep2Spells = true,
			KeepRarities = {
				["ultimate"] = true,
				["legendary"] = true,
				["epic"] = false,
				["rare"] = false,
				["uncommon"] = false,
				["common"] = false,
			},
			KeepList = {
				["Enhanced Inner Rage"] = { "legendary" },
				["Akuma Mage Robes"] = { "epic" },
				["Sacrificial Orbs"] = { "epic" },
			},
		},
	},
	CustomUi = {
		Enabled = true,
		Exp = "",
		Gold = "",
		Name = "",
		Level = "",
		Health = "",
		Image = "",
	},
	Universal = {
		Webhook = {
			Enabled = true,
			Url = "",
		},
	},
}

-- Global Functions
local function GetInventory(): {}
	return Remotes:WaitForChild("reloadInvy"):InvokeServer()
end

-- Auto Sell Functions
local function CheckRarity(name, rare): boolean
	-- Gets The Config Keep Inventory
	for Item, Rarity in next, Config.LobbySettings.AutoSell.KeepList do
		-- Getting All The Rarities To Keep For That Item
		for _, KeepRarity in next, Rarity do
			-- Comparing The Given Item And Rarity To The Keep List
			if name == Item and rare == KeepRarity then
				return false
			else
				return true
			end
		end
	end
	return not Config.LobbySettings.AutoSell.KeepRarities[rare]
end

local function Sell()
	if Config.LobbySettings.AutoSell.Enabled then
		local List = {}
		local Inventory = GetInventory()

		-- Getting The Item Folder Within The Inventory
		for FolderName, ItemFolder in next, Inventory do
			if
				FolderName == "helmets"
				or FolderName == "rings"
				or FolderName == "weapons"
				or FolderName == "chests"
			then
				-- Looping Through The Folder To Get The Items
				for index, Item in next, ItemFolder do
					-- Checking The Item Meets The Reqs

					if
						not Item.equipped
						and CheckRarity(Item.name, Item.rarity) == true
						and Item.levelReq < Config.LobbySettings.AutoSell.ItemLevelRequirement
					then
						print(Item.name)
						print(Item.imageId)

						local ItemSlot = tonumber(string.gsub(index, "%D", ""))
						print("Type: " .. type(ItemSlot) .. " Value: " .. ItemSlot)

						if
							FolderName == "weapons"
							and not Item.description
							and not Item.effects
							and not Item.health
							and not Item.favorite
						then
							if not Config.LobbySettings.AutoSell.TestSell then
								Remotes:WaitForChild("sellItemEvent"):FireServer({
									[1] = {
										["chest"] = {},
										["helmet"] = {},
										["ability"] = {},
										["ring"] = {},
										["weapon"] = { ItemSlot },
									},
								})
							else
								print("Test Sell: " .. Item.name)
							end
						elseif
							FolderName == "helmets"
							and not Item.description
							and not Item.effects
							and not Item.favorite
						then
							if not Config.LobbySettings.AutoSell.TestSell then
								Remotes:WaitForChild("sellItemEvent"):FireServer({
									[1] = {
										["chest"] = {},
										["helmet"] = { ItemSlot },
										["ability"] = {},
										["ring"] = {},
										["weapon"] = {},
									},
								})
							else
								print("Test Sell: " .. Item.name)
							end
						elseif
							FolderName == "chests"
							and not Item.description
							and not Item.effects
							and not Item.favorite
						then
							if not Config.LobbySettings.AutoSell.TestSell then
								Remotes:WaitForChild("sellItemEvent"):FireServer({
									[1] = {
										["chest"] = { ItemSlot },
										["helmet"] = {},
										["ability"] = {},
										["ring"] = {},
										["weapon"] = {},
									},
								})
							else
								print("Test Sell: " .. Item.name)
							end
						elseif FolderName == "rings" and not Item.favorite and Item.effects then
							if not Config.LobbySettings.AutoSell.TestSell then
								Remotes:WaitForChild("sellItemEvent"):FireServer({
									[1] = {
										["chest"] = {},
										["helmet"] = {},
										["ability"] = {},
										["ring"] = { ItemSlot },
										["weapon"] = {},
									},
								})
							else
								print("Test Sell: " .. Item.name)
							end
						end
					end
				end
			elseif FolderName == "abilities" then
				for index, Item in next, ItemFolder do
					if List[Item.name] then
						List[Item.name] += 1
					else
						List[Item.name] = 1
					end

					print(Item.name)
					print(Item.imageId)

					local ItemSlot = string.gsub(index, "%D", "")
					print("Type: " .. type(ItemSlot) .. " Value: " .. ItemSlot)

					if not Item.equipped.e and not Item.equipped.q then
						if
							CheckRarity(Item.name, Item.rarity)
							and Item.levelReq < Config.LobbySettings.AutoSell.ItemLevelRequirement
						then
							if Config.LobbySettings.AutoSell.Keep2Spells and List[Item.name] > 2 then
								if not Config.LobbySettings.AutoSell.TestSell then
									Remotes:WaitForChild("sellItemEvent"):FireServer({
										[1] = {
											["chest"] = {},
											["helmet"] = {},
											["ability"] = { ItemSlot },
											["ring"] = {},
											["weapon"] = {},
										},
									})
								else
									print("Test Sell: " .. Item.name)
								end
							end
						end
					end
				end
			end
		end
	end
end

warn("Script Ready")

task.wait(5)

Sell()
