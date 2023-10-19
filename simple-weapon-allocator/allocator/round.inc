enum RoundType {
	FULL_BUY_ROUND, 
	PISTOL_ROUND, 
	DEAGLE_ROUND
};

static const char roundName[][] = {
  "FULL BUY ROUND",
  "PISTOL ROUND",
  "DEAGLE ROUND"
};

static const int roundMoney[] = { 
  5000, 
  1000, 
  800 
};

RoundType RTYPE = FULL_BUY_ROUND;

stock void getRoundLoadout(int outGuns[2]){
  if(RTYPE == PISTOL_ROUND){
    outGuns[0] = -1;
  }else if(RTYPE == DEAGLE_ROUND){
    outGuns[0] = -1;
    outGuns[1] = 7;
  }
}

stock void prepareNewRound(char message[64]){
  // find new round
  RTYPE = view_as<RoundType>(GetRandomInt(0, 2));
  Format(message, sizeof(message), " \x08[\x03Legion7\x08] \x01Now is \x10%s", roundName[RTYPE]);
}

stock int getRoundMoney(){
  return roundMoney[RTYPE];
}
