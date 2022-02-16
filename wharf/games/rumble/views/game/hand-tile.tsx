import { TileData } from "@port7/dock/lib/games/rumble";
import React from "react";

export interface HandTileProps {
  data: TileData;
}

// TODO: universal colors something
const colors: string[] = ["#ff0000", "#00ff00", "#0000ff", "#ffa500"];

export const HandTile: React.FC<HandTileProps> = ({ data }) => {
  return (
    <div className="w-20 m-2 h-full bg-primary-700 rounded-md flex items-center justify-center cursor-pointer">
      <div style={{ color: colors[data.color - 1] }}>
        <h1 className="text-5xl select-none">
          {data.value != -1 ? data.value : "J"}
        </h1>
      </div>
    </div>
  );
};
