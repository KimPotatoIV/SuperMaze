extends Node2D

##################################################
enum TILE
{
	WALL,
	PATH,
	START_END
}
# 각 타일(셀)의 종류를 나타내는 열거형(벽, 길, 시작/끝)

##################################################
const OFFSET: int = 30
# 가장자리 둘레 너비
const CELL_SIZE: int = 20
# 한 셀의 너비
const MAZE_SIZE: int = 51
# 미로 셀 개수. 홀수이어야 함. 셀과 셀 사이에 벽을 그려야 하기 때문
const START_POSITION: Vector2 = Vector2(0, 0)
# 시작 위치
const END_POSITION: Vector2 = Vector2(MAZE_SIZE - 1, MAZE_SIZE - 1)
# 끝 위치

const WALL_TEXTURE: Texture = preload("res://scenes/maze/wall.png")
const PATH_TEXTURE: Texture = preload("res://scenes/maze/path.png")
const START_END_TEXTURE: Texture = preload("res://scenes/maze/start_end.png")
#타일(셀) 텍스처 미리 로드

var maze_array: Array = []
# 미로 배열
var stack: Array = []
# 스택 배열. 실제 스택은 아니지만, 연산 중 스택처럼 사용하려 함
var visited_array: Array = []
# 이미 방문한 배열

##################################################
func _ready() -> void:
	init_maze()
	# 미로를 만들기 위한 초기화 작업 함수
	generate_maze()
	# 미로 만들기 함수
	draw_maze()
	# 미로 그리기 함수
	

##################################################
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
	# space를 누를 때
		draw_solution_maze(solve_maze())
		# 미로 해답을 찾고 그리는 함수
	elif Input.is_action_just_pressed("ui_cancel"):
	# esc를 누를 때
		reset_maze()
		# 미로 재생성 함수
	
##################################################
func init_maze() -> void:
	for row in range(MAZE_SIZE):
		var insert_array = []
		for column in range(MAZE_SIZE):
			insert_array.append(TILE.WALL)
		maze_array.append(insert_array)
# 미로를 행과 열 단위로 나누어 벽으로 설정

##################################################
func generate_maze() -> void:
	stack.append(START_POSITION)
	# 스택에 시작 위치를 입력
	var current_cell = stack.back()
	# 현재 셀을 스택의 마지막으로 설정
	maze_array[current_cell.y][current_cell.x] = TILE.PATH
	# 시작 위치(현재 셀)를 길로 설정
	'''
	0	1	0	1
	0	1	0	1
	0	1	0	1
	0	1	0	1
	이렇게 봤을 때 0101이 행이고, 0000 혹은 1111이 열이기 때문에
	maze_array[current_cell.y][current_cell.x]에서 x와 y의 순서를 유의해서 넣어야 함
	'''
	
	while stack.size() > 0:
	# 스택이 empty가 아닌 동안
		var neighbors_cell_array = get_neighbors_cell(current_cell, 2)
		# 벽을 감안하여 두 칸 떨어진 위치의 셀을 확인 후 유효한 셀만 순서를 섞은 후 반환 받음
		
		if neighbors_cell_array.size() > 0:
		# 반환 받은 배열이 empty가 아니라면
			var middle_cell = (current_cell + neighbors_cell_array.front()) / 2
			maze_array[middle_cell.y][middle_cell.x] = TILE.PATH
			# 반환 받은 배열의 맨 앞 좌표와 현재 좌표 사이를 통로로 만듦
			
			current_cell = neighbors_cell_array.pop_front()
			stack.append(current_cell)
			maze_array[current_cell.y][current_cell.x] = TILE.PATH
			# 현재 셀을 반환 받은 배열의 맨 앞 좌표로 설정 후 스택에 입력 후 통로로 만듦
		else:
		# 반환 받은 배열이 empty라면
			stack.pop_back()
			# 스택 맨 뒤를 제거
			if stack.size() > 0:
			# 시작 위치로 돌아오는 경우를 감안하여 확인
				current_cell = stack.back()
				# 현재 셀을 스택의 맨 뒤 인자로 설정
		
##################################################
func get_neighbors_cell(cell: Vector2, distance: int) -> Array:
	var return_array = []
	if is_valid_cell(Vector2(cell.x, cell.y - distance), distance):
		return_array.append(Vector2(cell.x, cell.y - distance))
	if is_valid_cell(Vector2(cell.x, cell.y + distance), distance):
		return_array.append(Vector2(cell.x, cell.y + distance))
	if is_valid_cell(Vector2(cell.x - distance, cell.y), distance):
		return_array.append(Vector2(cell.x - distance, cell.y))
	if is_valid_cell(Vector2(cell.x + distance, cell.y), distance):
		return_array.append(Vector2(cell.x + distance, cell.y))
	
	return_array.shuffle()
	
	return return_array
# 한 칸이나 두 칸 떨어진 셀을 확인 후 유효할 경우 순서를 섞은 후 반환

##################################################
func is_valid_cell(cell: Vector2, distance: int) -> bool:
	if cell.x < 0 or cell.x >= MAZE_SIZE or \
		cell.y < 0 or cell.y >= MAZE_SIZE:
			return false
	# 미로 밖으로 벗어나지 않는지 확인 후 반환
	
	if distance == 2:
		if maze_array[cell.y][cell.x] == TILE.WALL:
			return true
	# 두 칸 떨어진 셀을 확인하는 경우 벽인지 확인 후 반환
	else:
		if maze_array[cell.y][cell.x] == TILE.PATH and\
		not visited_array.has(cell):
			return true
	# 한 칸 떨어진 셀을 확인하는 경우 길인지, 그리고 방문 했던 셀이 아닌지 확인 후 반환
	
	return false

##################################################
func draw_maze() -> void:
	maze_array[START_POSITION.x][START_POSITION.y] = TILE.START_END
	maze_array[END_POSITION.x][END_POSITION.y] = TILE.START_END
	# 시작/끝 위치를 시작/끝 타일(셀)로 설정
	
	for row in range(MAZE_SIZE):
		for column in range(MAZE_SIZE):
			var sprite = Sprite2D.new()
			# 스프라이트 변수를 선언 및 초기화
			var tile = maze_array[row][column]
			# 타일 변수를 선언 및 초기화
			
			if tile == TILE.WALL:
				sprite.texture = WALL_TEXTURE
			elif tile == TILE.PATH:
				sprite.texture = PATH_TEXTURE
			elif tile == TILE.START_END:
				sprite.texture = START_END_TEXTURE
			# 각 상황에 맞는 타일 변수 설정
			
			sprite.position = Vector2(CELL_SIZE * column + OFFSET, CELL_SIZE * row + OFFSET)
			sprite.centered = false
			add_child(sprite)
			# 위치에 맞게 좌표 설정 및 자식 노드로 추가

##################################################
func solve_maze() -> Array:
	stack.append(START_POSITION)
	# 스택(해답 배열)에 시작 위치를 입력
	visited_array.append(stack.back())
	# 방문 배열에 시작 위치를 입력
	var current_cell = stack.back()
	# 현재 셀을 스택(해답 배열)의 마지막으로 설정
	
	maze_array[END_POSITION.x][END_POSITION.y] = TILE.PATH
	# 해답 도출 시 오류를 없애기 위해 시작 위치(현재 셀)를 다시 길로 설정
	
	while stack.size() > 0:
	# 스택(해답 배열)이 empty가 아닌 동안
		if current_cell == END_POSITION:
			break
		# 현재 셀이 끝 위치이면 반복 종료
			
		var neighbors_cell_array = get_neighbors_cell(current_cell, 1)
		# 한 칸 떨어진 위치의 셀을 확인 후 유효한 셀만 순서를 섞은 후 반환 받음
		if neighbors_cell_array.size() > 0:
		# 반환 받은 배열이 empty가 아니라면
			current_cell = neighbors_cell_array.pop_front()
			# 현재 셀을 반환받은 배열의 맨 앞 인자로 설정
			stack.append(current_cell)
			# 스택(해답 배열)도 동일하게 설정
			visited_array.append(stack.back())
			# 이미 방문한 배열도 동일하게 설정
		else:
		# 반환 받은 배열이 empty라면
			stack.pop_back()
			# 스택(해답 배열) 인자 하나 제거
			current_cell = stack.back()
			# 현재 셀을 스택(해답 배열) 마지막 인자로 설정
	
	return stack
	# 스택(해답 배열) 배열 반환

##################################################
func draw_solution_maze(path: Array) -> void:
	for cell in range(path.size()):
	# 해답 배열을 순회하며
		var sprite = Sprite2D.new()
		sprite.texture = START_END_TEXTURE
		sprite.position = \
		Vector2(CELL_SIZE * path[cell].x + OFFSET, CELL_SIZE * path[cell].y + OFFSET)
		sprite.centered = false
		add_child(sprite)
		# 스프라이트 변수 설정 및 자식 노드로 추가

##################################################
func reset_maze() -> void:
	for node in get_children():
		if node is Sprite2D:
			remove_child(node)
			node.queue_free()
	# 모든 자식 노드를 순회하여 삭제
			node = null
			# 명시적으로 null로 설정하여 참조 해제
	
	maze_array.clear()
	stack.clear()
	visited_array.clear()
	# 각 배열들 초기화
	
	init_maze()
	generate_maze()
	draw_maze()
	# 미로를 다시 만들어 그림
