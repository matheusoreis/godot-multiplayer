extends Node
class_name Constants


const DATABASE_PATH: String = "user://database/"
const DATABASE_FILENAME: String = "database"


const ENDPOINT: String = "0.0.0.0:4242"
const MAX_PEERS: int = 100


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


const START_MAP: int = 1
const START_MAP_POSITION: Vector2i = Vector2i(1, 1)
const START_MAP_FACING: Vector2i = Vector2i.DOWN

const MAP_MIN_SIZE: Vector2i = Vector2i(40, 18)


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


const CHARACTER_STEP_INTERVAL_MS: int = 200

const NPC_DECISION_INTERVAL_MIN: float = 1.0
const NPC_DECISION_INTERVAL_MAX: float = 3.0

const NPC_STEP_INTERVAL: float = 0.2

const NPC_MIN_STEPS_PER_MOVE: int = 1
const NPC_MAX_STEPS_PER_MOVE: int = 10


const ROLE_NONE: int = 0
const ROLE_MODERATOR: int = 1
const ROLE_ADMIN: int = 2
