extends Resource
class_name Element

@export var name : String
@export var atomic_number : int
@export var symbol : String
@export var natural : bool
@export var has_temp_data := false
@export var melting_point : float
@export var boiling_point : float

enum Category {Nonmetal, NobleGas, AlkaliMetal, AlkaliEarthMetal, Halogen, Metal, Metalloid, TransitionMetal, Lanthanide, Actinide, Transactinide, Unknown}
@export var category : Category
