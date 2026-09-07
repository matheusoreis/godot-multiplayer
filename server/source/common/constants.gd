extends Node
class_name Constants


const DATABASE_PATH: String = "user://database/"
const DATABASE_FILENAME: String = "database"
const DATABASE_POLL_TIME: int = 1



const HOST: String = "0.0.0.0"
const PORT: int = 7001


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


const AVALIABLE_SPRITES: Array[String] = ["fighter01", "fighter02"]
