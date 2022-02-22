import React from "react";
import { GameMilestone } from "@port7/dock/lib/games/rumble";
import { useRumbleStore } from "../../use-rumble-store";
import { useDrag } from "@use-gesture/react";
import { animated, useSprings, config } from "react-spring";
import swap from "lodash-move";

export interface TileBounds {
  x: number;
  y: number;
}

const WIDTH = 90;
const HEIGHT_CUTOFF = -140;
const colors: string[] = ["#ff0000", "#00ff00", "#0000ff", "#ffa500"];

const clamp = (num: number, min: number, max: number) =>
  Math.min(Math.max(num, min), max);

const fn =
  (
    order: number[],
    matrixScale: number,
    active = false,
    originalIndex = 0,
    curIndex = 0,
    x = 0,
    y = 0
  ) =>
  (index: number) =>
    active && index === originalIndex
      ? {
          x: curIndex * WIDTH + x,
          y: y,
          scale: y > HEIGHT_CUTOFF ? 1.1 : matrixScale * 1.25,
          zIndex: 1,
          shadow: 15,
          immediate: (key: string) => key === "zIndex",
          config: (key: string) =>
            key === "x" ? config.stiff : config.default,
        }
      : {
          x: order.indexOf(index) * WIDTH,
          y: 0,
          scale: 1,
          zIndex: 0,
          shadow: 1,
          immediate: false,
        };

export interface HandProps {
  matrixScale: number;
}

export const Hand: React.FC<HandProps> = ({ matrixScale }) => {
  const state = useRumbleStore();
  const milestone = state.milestone as GameMilestone;
  const hand = milestone.me.hand;
  const order = React.useRef(hand.map((_, i) => i));

  const [springs, setSprings] = useSprings(
    hand.length,
    fn(order.current, matrixScale),
    [hand]
  );
  const bind = useDrag(
    ({ args: [originalIndex], active, movement: [x, y] }) => {
      let curIndex = order.current.indexOf(originalIndex);
      if (curIndex === -1) {
        curIndex = 7;
      }
      console.log(curIndex);

      const curRow = clamp(
        Math.round((curIndex * WIDTH + x) / WIDTH),
        0,
        hand.length - 1
      );
      const newOrder = swap(order.current, curIndex, curRow);
      setSprings.start(
        fn(newOrder, matrixScale, active, originalIndex, curIndex, x, y)
      ); // Feed springs new style data, they'll animate the view without causing a single render
      if (!active) order.current = newOrder;
    }
  );

  return (
    <div className="flex border-t-2 border-primary-700 bg-primary-800 h-auto pt-4 pb-2 relative justify-center">
      <div className="h-24 block" style={{ width: hand.length * WIDTH }}>
        {springs.map(({ zIndex, shadow, x, y, scale }, i) => (
          <animated.div
            {...bind(i)}
            key={i}
            className="absolute bg-primary-600 rounded-lg flex items-center justify-center"
            style={{
              width: "80px",
              height: "104px",
              zIndex,
              boxShadow: shadow.to(
                (s) => `rgba(0, 0, 0, 0.15) 0px ${s}px ${2 * s}px 0px`
              ),
              x,
              y,
              scale,
              touchAction: "none",
            }}
          >
            <h1
              className="select-none text-5xl"
              style={{ color: colors[hand[i].color - 1] }}
            >
              {hand[i].value}
            </h1>
          </animated.div>
        ))}
      </div>
      <button
        className="absolute left-20 bottom-20 bg-primary-200"
        onClick={() => {
          let newOrder = Array.from(order.current);
          newOrder.push(newOrder.length);
          order.current = newOrder;
          state.addHandTile({ color: 1, value: 1 });
          setSprings.start(fn(newOrder, matrixScale));

          setTimeout(() => {
            console.log(order.current);
          }, 1000);
        }}
      >
        CLICK ME
      </button>
    </div>
  );
};
