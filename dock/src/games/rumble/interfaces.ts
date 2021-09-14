export interface Peer {
  id: number;
  nickname: string;
  isDisconnected: boolean;
}

export interface BaseMilestone {
  state: string;
}

export interface LobbyMilestone extends BaseMilestone {
  startTime: number | undefined;
}

export interface GameMilestone extends BaseMilestone {
  currentTurn: number;
}

export type Milestone = LobbyMilestone | GameMilestone;
