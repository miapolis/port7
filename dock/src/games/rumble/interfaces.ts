export interface Peer {
  id: number;
  nickname: string;
  isDisconnected: boolean;
}

export interface Tile {
  id: number;
  x: number;
  y: number;
}

export interface BaseMilestone {
  state: string;
}

export interface LobbyMilestone extends BaseMilestone {
  startTime: number | undefined;
}

export interface GameMilestone extends BaseMilestone {
  currentTurn: number;
  tiles: Map<number, Tile>;
}

export type Milestone = LobbyMilestone | GameMilestone;
