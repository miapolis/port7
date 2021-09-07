import React from "react";

export type ButtonColor = "accent" | "secondary" | "ternary";

export interface ButtonProps {
  color?: ButtonColor;
  padding?: "normal" | "large";
  onClick?: () => void;
}

export const Button: React.FC<ButtonProps> = ({
  color,
  padding,
  onClick,
  children,
}) => {
  let classColor, classPadding;

  switch (color) {
    case undefined:
    case "accent":
      classColor = "bg-accent hover:bg-accent-hover";
      break;
    case "secondary":
      classColor = "bg-secondary hover:bg-secondary-hover";
      break;
    case "ternary":
      classColor = "bg-ternary hover:bg-ternary-hover";
      break;
  }

  switch (padding) {
    case undefined:
    case "normal":
      classPadding = "p-3";
      break;
    case "large":
      classPadding = "p-4";
      break;
  }

  return (
    <button
      onClick={onClick}
      className={`${classColor} text-primary-100 ${classPadding} font-bold rounded-md shadow-md transition-all`}
    >
      {children}
    </button>
  );
};
