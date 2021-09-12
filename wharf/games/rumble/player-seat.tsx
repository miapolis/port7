import React from "react";
import { useTransition, animated } from "react-spring";

export interface PlayerSeatProps {
  angle: number;
  nickname: string;
}

export const PlayerSeat: React.FC<PlayerSeatProps> = ({
  angle,
  nickname,
}: PlayerSeatProps) => {
  const transition = useTransition(null, {
    config: { mass: 10, tension: 500, friction: 0, clamp: true },
    from: { opacity: 0, y: 10 },
    enter: { opacity: 1, y: 0 },
    leave: { opacity: 0, y: 0 },
  });

  return (
    <div className="absolute pointer-events-none">
      {transition((style, _item) => {
        return (
          <animated.div
            className="relative pointer-events-none"
            style={{
              width: 500,
              height: 500,
              transform: `rotate(${angle}deg)`,
              transition: "transform 0.7s",
              ...style,
            }}
          >
            <div
              className="absolute flex items-center justify-center bg-primary-700 rounded-full"
              style={{
                transform: `rotate(${angle * -1}deg)`,
                bottom: "-45px",
                left: "205px",
                width: 90,
                height: 90,
                transition: "transform 0.7s",
              }}
            >
              <span
                className="text-primary-100 text-center table-cell"
                style={{ verticalAlign: "middle", lineHeight: "normal" }}
              >
                {nickname}
              </span>
            </div>
          </animated.div>
        );
      })}
    </div>
  );
};
