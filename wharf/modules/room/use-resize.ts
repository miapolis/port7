import React from "react";

const getWindowsSize = () => {
  return { x: window.innerWidth, y: window.innerHeight };
};

export const useResize = () => {
  const [size, setSize] = React.useState(getWindowsSize());

  const handleResize = React.useCallback(() => {
    setSize(getWindowsSize());
  }, []);

  React.useEffect(() => {
    window.addEventListener("resize", handleResize, { passive: true });
    return () => {
      window.removeEventListener("resize", handleResize);
    };
  }, [handleResize]);

  return size;
};
