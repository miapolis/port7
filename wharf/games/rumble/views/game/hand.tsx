import React from "react";
import { GameMilestone } from "@port7/dock/lib/games/rumble";
import { useRumbleStore } from "../../use-rumble-store";

export const Hand: React.FC = () => {
  const state = useRumbleStore();
  const milestone = state.milestone as GameMilestone;

  return <div className="flex-shrink-0 border-t-2 border-primary-700 bg-primary-800 w-full h-32 z-50">
    <div className="w-full h-full p-2">
      {milestone.me.hand.find(x => true)?.color}
    </div>
  </div>;
};
