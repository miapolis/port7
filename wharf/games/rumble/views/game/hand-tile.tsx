import React from "react";
import { TileData } from "@port7/dock/lib/games/rumble";
import Draggable, { DraggableData, DraggableEvent } from "react-draggable";
import { TileBounds } from "./hand";

export interface HandTileProps {
  data: TileData;
  bounds: TileBounds;
  onDrag: (x: number, y: number, ref: React.RefObject<HTMLDivElement>) => void;
  style?: React.CSSProperties;
}

// TODO: universal colors something
const colors: string[] = ["#ff0000", "#00ff00", "#0000ff", "#ffa500"];

export const HandTile: React.FC<HandTileProps> = ({
  data,
  bounds,
  onDrag,
  style,
}) => {
  const selfRef = React.useRef<HTMLDivElement>(null);

  const onDragThis = (e: DraggableEvent, data: DraggableData) => {
    onDrag(data.deltaX, data.deltaY, selfRef);
  };

  return (
    <div style={style} ref={selfRef}>
      <Draggable
        onDrag={onDragThis}
        position={{ x: bounds ? bounds.x : 0, y: bounds ? bounds.y : 0 }}
      >
        <div className="w-20 m-2 h-full bg-primary-700 rounded-md flex items-center justify-center cursor-move">
          <div style={{ color: colors[data.color - 1] }}>
            <h1 className="text-5xl select-none">
              {data.value != -1 ? data.value : "J"}
            </h1>
          </div>
        </div>
      </Draggable>
    </div>
  );
};
