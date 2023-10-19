enum GameState {	
	LOBBY = 0,
	IN_GAME
};

GameState gState = LOBBY;

stock void SetGameState(GameState newState){
	gState = newState;
}

stock GameState GetGameState(){
	return gState;
}

stock bool GameInProgress(){
	return gState == IN_GAME;
}