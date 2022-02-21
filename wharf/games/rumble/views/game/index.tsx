import React from "react";
import { TileContainer } from "./tile-container";
import { rumbleDebugTiles } from "@port7/lib/constants";
import { TileGui } from "./debug/tile-gui";
import { Hand } from "./hand";

export const Game = () => {
  return (
    <div className="relative w-full h-full flex-shrink">
      <TileContainer />
      <div className="w-full h-full flex flex-col">
        <div className="flex-1" />
        <Hand />
      </div>
      {rumbleDebugTiles ? <TileGui /> : ""}
    </div>
  );
};
