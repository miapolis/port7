import React from "react";
import { TileObject } from "@port7/dock/lib/games/rumble";
import { DraggableCore, DraggableData, DraggableEvent } from "react-draggable";
import { SNAP_END_DELAY_MS, AREA_WIDTH, AREA_HEIGHT } from "./tile-container";
import { rumbleDebugTiles } from "@port7/lib/constants";

export interface TileProps {
  id: number;
  data: TileObject;
  scale: number;
  onDrag: (event: any) => void;
  onDragStop: (id: number) => void;
  onHover: (hover: boolean) => void;
}

const colors: string[] = ["#ff0000", "#00ff00", "#0000ff", "#ffa500"];

export const Tile: React.FC<TileProps> = ({
  id,
  data,
  scale,
  onDrag,
  onDragStop,
  onHover,
}) => {
  const [hovered, setHovered] = React.useState(false);
  const onDragThis = (e: DraggableEvent, data: DraggableData) => {
    onDrag({
      id: id,
      deltaX: Math.round(data.deltaX / scale),
      deltaY: Math.round(data.deltaY / scale),
    });
  };

  return (
    <DraggableCore onDrag={onDragThis} onStop={() => onDragStop(id)}>
      <div
        className={`rounded-lg bg-primary-600 absolute cursor-move shadow-lg ${
          data.isDragging || data.isServerMoving ? "z-10" : ""
        }`}
        style={{
          position: "absolute",
          width: "100px",
          height: "130px",
          background: hovered ? "#3a4659ff" : "",
          transition:
            data.isSnapping || data.isServerMoving
              ? `background 0.3s, transform ${SNAP_END_DELAY_MS / 1000}s`
              : "background 0.3s",
          transform: `translate(${data.lockedX ?? data.x + AREA_WIDTH / 2}px, ${
            data.lockedY ?? data.y + AREA_HEIGHT / 2
          }px)`,
        }}
        onMouseEnter={() => {
          setHovered(true);
          onHover(true);
        }}
        onMouseLeave={() => {
          setHovered(false);
          onHover(false);
        }}
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
          )}{" "}
          <div
            className="flex h-full w-full justify-center items-center"
            style={{
              userSelect: "none",
              color: `${colors[data.data.color - 1]}`,
            }}
          >
            <h1>{data.data.value != -1 ? data.data.value : "J"}</h1>
          </div>
          {rumbleDebugTiles ? (
            <div
              style={{ userSelect: "none" }}
              className="absolute top-2 left-2 text-primary-100"
            >
              {`${data.id} ${
                data.groupId !== null && data.groupId !== undefined
                  ? "- " + data.groupId
                  : ""
              }`}
            </div>
          ) : (
            ""
          )}
        </div>
      </div>
    </DraggableCore>
  );
};
