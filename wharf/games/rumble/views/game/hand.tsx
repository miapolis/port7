import React from "react";
import { GameMilestone } from "@port7/dock/lib/games/rumble";
import { useRumbleStore } from "../../use-rumble-store";
import { HandTile } from "./hand-tile";
import Draggable, {
  DraggableCore,
  DraggableData,
  DraggableEvent,
} from "react-draggable";

export interface TileBounds {
  x: number;
  y: number;
}

export const Hand: React.FC = () => {
  const state = useRumbleStore();
  const milestone = state.milestone as GameMilestone;
  const hand = milestone.me.hand;

  return (
    <div className="flex border-t-2 border-primary-700 bg-primary-800 h-auto pt-4 pb-2 relative justify-center">
      <div className="flex overflow-x-scroll">
        <div className="h-24 flex">
          {hand.map((tile, i) => {
            return (
              <div className="h-24 mx-2 bg-primary-100 w-20 flex-shrink-0" />
            );
          })}
        </div>
      </div>
    </div>
  );
};
