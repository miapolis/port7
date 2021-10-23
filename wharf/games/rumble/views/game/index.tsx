import React from "react";
import { TileContainer } from "./tile-container";
import { rumbleDebugTiles } from "@port7/lib/constants";
import { TileGui } from "./debug/tile-gui";

export const Game = () => {
  return (
    <>
      <TileContainer />
      {rumbleDebugTiles ? <TileGui /> : ""}
    </>
  );
};
