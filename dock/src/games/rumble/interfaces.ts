export interface Peer {
  id: number;
  nickname: string;
  isDisconnected: boolean;
}

export type GroupType = "set" | "run";

export interface Group {
  id: number;
  children: Map<number, number>;
  groupType: GroupType;
}

export interface Tile {
  id: number;
  x: number;
  y: number;
  groupId: number | undefined;
  groupIndex: number | undefined;
}

export interface TileObject extends Tile {
  lockedX: number | undefined;
  lockedY: number | undefined;
  snapSide: 0 | 1 | undefined;
  isDragging: boolean;
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
  groups: Map<number, Group>;
}

export type Milestone = LobbyMilestone | GameMilestone;
