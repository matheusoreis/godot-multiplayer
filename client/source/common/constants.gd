extends Node
class_name Constants


const MAPS_DATA_DIRECTORY: String = "res://data/maps/"
const TILESET_DATA_DIRECTORY: String = "res://data/tilesets/"

const CHARACTER_SPRITE_DIRECTORY: String = "res://assets/gfx/characters/"
const TILESET_SPRITE_DIRECTORY: String = "res://assets/gfx/tilesets/"


const ENDPOINT: String = "127.0.0.1:4242"


const MAJOR_VERSION: int = 1
const MINOR_VERSION: int = 0
const REVISION_VERSION: int = 0


const CELL_SIZE: int = 32

const CELL_NONE: int = 0
const CELL_FULL_BLOCK: int = 1
const CELL_UP: int = 2
const CELL_RIGHT: int = 4
const CELL_DOWN: int = 8
const CELL_LEFT: int = 16


const IDENTIFIER_REGEX: String = "^[a-zA-Z0-9]{3,}$"
const EMAIL_REGEX: String = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
const PASSWORD_REGEX: String = "^(?=.*[0-9])(?=.*[!@#$%^&*(),.?\":{}|<>]).{4,}$"


const AVALIABLE_SPRITES: Array[String] = [
	"cleric01",
	"cleric02",
	"cleric03",
	"cleric04",
	"cleric05",
	"cleric06",
	"cleric07",
	"cleric08",
	"fighter01",
	"fighter02",
	"fighter03",
	"fighter04",
	"fighter05",
	"fighter06",
	"fighter07",
	"fighter08",
	"gunner01",
	"gunner02",
	"hunter01",
	"hunter02",
	"hunter03",
	"lancer01",
	"lancer02",
	"lancer03",
	"lancer04",
	"mage01",
	"mage02",
	"mage03",
	"mage04",
	"mage05",
	"mage06",
	"mage07",
	"mage08",
	"mage09",
	"thief01",
	"thief02",
	"thief03",
	"thief04",
	"warrior01",
	"warrior02",
	"warrior03"
]


const SPRITESHEET_COLUMNS: int = 3
const SPRITESHEET_ROWS: int = 4

const ANIMATION_STEP_THRESHOLD: float = 0.5

const WALKING_SPEED: float = 5.0
const MAX_PENDING_MOVES: int = 32

const WARP_COOLDOWN: float = 0.3


const ROLE_NONE: int = 0
const ROLE_MODERATOR: int = 1
const ROLE_ADMIN: int = 2
