extends Node

const CastleGameMode := preload('res://scripts/castle_game_mode.gd')

const COURT_YARD = preload("res://scenes/maps/court_yard.tscn")
const DINING_HALL = preload("res://scenes/maps/dining_hall.tscn")
const INDOOR_CASTLE = preload("res://scenes/maps/indoor_castle.tscn")
const STAIRS = preload("res://scenes/maps/stairs.tscn")

func change_to_COURT_YARD():
	CastleGameMode.get_instance().change_map(COURT_YARD.instantiate())

func change_to_DINING_HALL():
	CastleGameMode.get_instance().change_map(DINING_HALL.instantiate())

func change_to_INDOOR_CASTLE():
	CastleGameMode.get_instance().change_map(INDOOR_CASTLE.instantiate())

func change_to_STAIRS():
	CastleGameMode.get_instance().change_map(STAIRS.instantiate())
