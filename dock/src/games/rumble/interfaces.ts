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

export interface TileObject {
  id: number;
  x: number;
  y: number;
  lockedX: number | undefined;
  lockedY: number | undefined;
  snapSide: 0 | 1 | undefined;
  isSnapping: boolean;
}

export interface BaseMilestone {
  state: string;
}

export interface LobbyMilestone extends BaseMilestone {
  startTime: number | undefined;
}

export interface GameMilestone extends BaseMilestone {
  currentTurn: number;
  tiles: Map<number, TileObject>;
}

export type Milestone = LobbyMilestone | GameMilestone;
