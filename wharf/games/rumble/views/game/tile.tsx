import React from "react";
import { DraggableCore, DraggableData, DraggableEvent } from "react-draggable";
import { SNAP_END_DELAY_MS, TileObject } from "./tile-container";

export interface TileProps {
  id: number;
  data: TileObject;
  onDrag: (event: any) => void;
  onDragStop: (id: number) => void;
}

export const Tile: React.FC<TileProps> = ({ id, data, onDrag, onDragStop }) => {
  const onDragThis = (e: DraggableEvent, data: DraggableData) => {
    onDrag({ id: id, deltaX: data.deltaX, deltaY: data.deltaY });
  };

  return (
    <DraggableCore onDrag={onDragThis} onStop={() => onDragStop(id)}>
      <div
        className="rounded-lg bg-primary-600 absolute"
        style={{
          width: "100px",
          height: "130px",
          transition: data.isSnapping ? `all ${SNAP_END_DELAY_MS / 1000}s` : "",
          transform: `translate(${data.lockedX ?? data.x}px, ${data.lockedY ?? data.y}px)`,
        }}
      >
        <div className="relative w-full h-full">
          {data.highlightRight === true ? (
            <div
              className="absolute h-full w-1 bg-secondary ring-2"
              style={{ right: "-4px", borderRadius: "4px" }}
            />
          ) : data.highlightRight === false ? (
            <div
              className="absolute h-full w-1 bg-secondary ring-2"
              style={{ left: "-4px", borderRadius: "4px" }}
            />
          ) : (
            ""
          )}
        </div>
      </div>
    </DraggableCore>
  );
};
