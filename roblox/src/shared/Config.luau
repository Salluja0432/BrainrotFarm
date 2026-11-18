local Config = {}

-- ===== AJUSTES DO JOGO (edite aqui) =====
Config.DataStoreName = "BrainrotFarm_v1"
Config.TransferDataStoreName = "BrainrotFarm_Transfers_v1" -- journal persistente de transferências
Config.DataVersion = 1
Config.StartingCoins = 100
Config.StartingCreature = "Gatomelo"
Config.EggPrice = 100           -- preço do ovo
Config.SellMultiplier = 10      -- venda = income x este valor
Config.MaxSlots = 6             -- slots de exibição na base
Config.StealCooldown = 15       -- segundos entre roubos do mesmo jogador
Config.ShieldTime = 30          -- segundos de proteção após ser roubado
Config.MaxOfflineSeconds = 3600 -- ganho offline máximo (1 hora)
Config.DataStoreMaxAttempts = 4
Config.DataStoreRetryDelay = 1
Config.DataStoreRetryMaxDelay = 8
Config.DataStoreRetryJitter = 0.25
Config.SessionLockTimeout = 180 -- sessão considerada abandonada após este tempo sem heartbeat
Config.SessionHeartbeatInterval = 45
Config.ShutdownSaveTimeout = 25

-- Economia atual: renda esperada do ovo = 12,85 moedas/s; valor esperado
-- de venda = 128,50 moedas (líquido esperado +28,50 sobre ovo de 100).
-- A venda tem retorno positivo esperado e deve ser rebalanceada antes de produção.
Config.Economy = {
	ExpectedIncomePerEgg = 12.85,
	ExpectedSellValuePerEgg = 128.50,
	ExpectedNetSellPerEgg = 28.50,
	ExpectedReturnOnCostPercent = 28.5,
	LossProbabilityPercent = 85,
}

-- Chances somam 100
Config.Rarities = {
	{ name = "Comum", chance = 60, income = 1, color = Color3.fromRGB(190, 190, 190) },
	{ name = "Rara", chance = 25, income = 5, color = Color3.fromRGB(70, 150, 255) },
	{ name = "Épica", chance = 10, income = 20, color = Color3.fromRGB(170, 70, 255) },
	{ name = "Lendária", chance = 4, income = 100, color = Color3.fromRGB(255, 180, 30) },
	{ name = "Divina", chance = 1, income = 500, color = Color3.fromRGB(255, 60, 120) },
}

-- Criaturas originais
Config.Creatures = {
	{ name = "Gatomelo", rarity = "Comum" },
	{ name = "Sapokito", rarity = "Comum" },
	{ name = "Pinguim Chiclete", rarity = "Comum" },
	{ name = "Dino Feijão", rarity = "Rara" },
	{ name = "Vaquinha Pizza", rarity = "Rara" },
	{ name = "Rato Foguete", rarity = "Épica" },
	{ name = "Coruja Neon", rarity = "Épica" },
	{ name = "Tubarão Sorvete", rarity = "Lendária" },
	{ name = "Rei Bolinho", rarity = "Divina" },
}

-- ===== lookups =====
Config.RarityByName = {}
for _, r in Config.Rarities do
	Config.RarityByName[r.name] = r
end

Config.ByName = {}
for _, c in Config.Creatures do
	Config.ByName[c.name] = c
end

function Config.info(name)
	local c = Config.ByName[name]
	if not c then
		return nil, nil
	end
	return c, Config.RarityByName[c.rarity]
end

function Config.sellValue(name)
	local _, r = Config.info(name)
	if not r then
		return 0
	end
	return r.income * Config.SellMultiplier
end

function Config.rollCreature()
	local roll = math.random(1, 100)
	local acc = 0
	for _, r in Config.Rarities do
		acc += r.chance
		if roll <= acc then
			local pool = {}
			for _, c in Config.Creatures do
				if c.rarity == r.name then
					table.insert(pool, c.name)
				end
			end
			return pool[math.random(1, #pool)]
		end
	end
	return Config.Creatures[1].name
end

return Config
