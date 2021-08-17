import React from "react";
import * as dock from "@port7/dock/lib";

interface WebSocketProviderProps {
  shouldConnect: boolean;
}

type V = dock.Connection | null;

export const WebSocketContext = React.createContext<{
  conn: V;
  setConn: (c: V) => void;
}>({ conn: null, setConn: () => {} });

export const WebSocketProvider: React.FC<WebSocketProviderProps> = ({
  shouldConnect,
  children,
}) => {
  const [conn, setConn] = React.useState<V>(null);
  const isConnecting = React.useRef(false);

  React.useEffect(() => {
    if (!conn && shouldConnect && !isConnecting.current) {
      isConnecting.current = true;
      dock
        .connect({ waitToReconnect: true })
        .then((x) => {
          console.log("CONN" + x);
          setConn(x);
        })
        .catch((err) => {
          console.log(err);
        })
        .finally(() => (isConnecting.current = false));
    }
  }, [conn, shouldConnect]);

  return (
    <WebSocketContext.Provider
      value={React.useMemo(
        () => ({
          conn,
          setConn,
        }),
        [conn]
      )}
    >
      {children}
    </WebSocketContext.Provider>
  );
};
