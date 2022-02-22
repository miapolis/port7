import create from "zustand";
import {
  GameMilestone,
  Milestone,
  Peer,
  Group,
  TileData,
  Tile,
  MeData,
} from "@port7/dock/lib/games/rumble";

interface RumbleState {
  landed: boolean;
  milestone: Milestone | undefined;
  joinedPeers: Map<number, Peer>;
  serverToLocalNow: number | undefined;
  doLanding: () => void;
  setMilestone: (milestone: Milestone) => void;
  setMeData: (meData: MeData) => void;
  setServerNow: (serverNow: number) => void;
  setStartTimestamp: (timestamp: number | undefined) => void;
  setJoinedPeers: (peers: Peer[]) => void;
  addJoinedPeer: (id: number, nickname: string) => void;
  removeJoinedPeer: (id: number) => void;
  updateTile: (tile: any) => void;
  updateGroup: (group: Group) => void;
  deleteGroup: (id: number) => void;
  addHandTile: (data: TileData) => void;
}

export const useRumbleStore = create<RumbleState>((set) => ({
  landed: false,
  milestone: undefined,
  joinedPeers: new Map<number, Peer>(),
  serverToLocalNow: undefined,
  doLanding: () => {
    set((_state) => ({
      landed: true,
    }));
  },
  setMilestone: (milestone: Milestone) => {
    set((_state) => ({
      milestone: milestone,
    }));
  },
  setMeData: (meData: MeData) => {
    set((state) => {
      const milestone = state.milestone as GameMilestone;
      return {
        milestone: { ...milestone, me: meData },
      };
    });
  },
  setServerNow: (serverNow: number) => {
    set((_state) => ({
      serverToLocalNow: Date.now() - serverNow,
    }));
  },
  setStartTimestamp: (timestamp: number | undefined) => {
    set((state) => {
      return {
        milestone: Object.assign(state.milestone, { startTime: timestamp }),
      };
    });
  },
  setJoinedPeers: (peers: Peer[]) => {
    set((_state) => {
      const mapped = new Map(peers.map((obj) => [obj.id, obj]));
      return { joinedPeers: mapped };
    });
  },
  addJoinedPeer: (id: number, nickname: string) => {
    set((state) => ({
      joinedPeers: state.joinedPeers.set(id, {
        id,
        nickname,
        isDisconnected: false,
      }),
    }));
  },
  removeJoinedPeer: (id: number) => {
    set((state) => {
      state.joinedPeers.delete(id);
      return {
        joinedPeers: state.joinedPeers,
      };
    });
  },
  updateTile: (tile: any) => {
    set((state) => {
      const milestone = state.milestone as GameMilestone;
      return {
        milestone: { ...milestone, tiles: milestone.tiles.set(tile.id, tile) },
      };
    });
  },
  updateGroup: (group: any) => {
    set((state) => {
      const milestone = state.milestone as GameMilestone;
      return {
        milestone: {
          ...milestone,
          groups: milestone.groups.set(group.id, group),
        },
      };
    });
  },
  deleteGroup: (id: number) => {
    set((state) => {
      const milestone = state.milestone as GameMilestone;
      milestone.groups.delete(id);
      return {
        milestone,
      };
    });
  },
  addHandTile: (data: TileData) => {
    set((state) => {
      const milestone = state.milestone as GameMilestone;
      const meData = milestone.me;
      meData.hand.push(data);

      return {
        milestone: { ...milestone, me: meData },
      };
    });
  },
}));
