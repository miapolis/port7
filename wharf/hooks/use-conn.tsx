import React from "react";
import { WebSocketContext } from "../modules/ws/ws-provider";

export const useConn = () => {
  return React.useContext(WebSocketContext).conn!;
}
