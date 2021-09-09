import React from "react";

export interface PlayerSeatProps {
  angle: number;
}

export const PlayerSeat: React.FC<PlayerSeatProps> = ({ angle }) => {
  return (
    <div className="absolute pointer-events-none">
      <div
        className="relative pointer-events-none"
        style={{
          width: 360,
          height: 360,
          transform: `rotate(${angle}deg)`,
          transition: "transform 0.7s",
        }}
      >
        <div
          className="absolute flex items-center justify-center"
          style={{
            transform: `rotate(${angle * -1}deg)`,
            bottom: "-30px",
            left: "150px",
            width: 60,
            height: 60,
            transition: "transform 0.7s"
          }}
        >
          <div className="text-primary-100">TEST</div>
        </div>
      </div>
    </div>
  );
};
