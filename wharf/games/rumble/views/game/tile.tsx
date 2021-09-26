import React from "react";
import { TileObject } from "@port7/dock/lib/games/rumble";
import { DraggableCore, DraggableData, DraggableEvent } from "react-draggable";
import { SNAP_END_DELAY_MS } from "./tile-container";

export interface TileProps {
  id: number;
  data: TileObject;
  onDrag: (event: any) => void;
  onDragStop: (id: number) => void;
}

export const Tile: React.FC<TileProps> = ({ id, data, onDrag, onDragStop }) => {
  const [hovered, setHovered] = React.useState(false);
  const onDragThis = (e: DraggableEvent, data: DraggableData) => {
    onDrag({ id: id, deltaX: data.deltaX, deltaY: data.deltaY });
  };

  return (
    <DraggableCore onDrag={onDragThis} onStop={() => onDragStop(id)}>
      <div
        className={`rounded-lg bg-primary-600 absolute cursor-move shadow-lg ${
          data.isDragging ? "z-10" : ""
        }`}
        style={{
          width: "100px",
          height: "130px",
          background: hovered ? "#3a4659ff" : "",
          transition: data.isSnapping
            ? `background 0.3s, transform ${SNAP_END_DELAY_MS / 1000}s`
            : "background 0.3s",
          transform: `translate(${data.lockedX ?? data.x}px, ${
            data.lockedY ?? data.y
          }px)`,
        }}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
      >
        <div className="relative w-full h-full">
          {data.snapSide === 1 ? (
            <div
              className="absolute h-full w-1 bg-secondary ring-2"
              style={{ right: "-4px", borderRadius: "4px" }}
            />
          ) : data.snapSide === 0 ? (
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