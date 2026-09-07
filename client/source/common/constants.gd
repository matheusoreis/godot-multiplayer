extends Node
class_name Constants


const HOST: String = "127.0.0.1"
const PORT: int = 7001


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


const AVALIABLE_SPRITES: Array[String] = ["fighter01", "fighter02"]
