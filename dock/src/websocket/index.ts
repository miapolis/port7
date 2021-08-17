import WebSocket from "isomorphic-ws";
import ReconnectingWebSocket from "reconnecting-websocket";
import { v4 as uuidV4 } from "uuid";

const API_BASE_URL = "ws://localhost:4001/socket";

const HEARTBEAT_INTERVAL = 8000;
const CONNECTION_TIMEOUT = 15000;

export type Opcode = string;

export interface Data {
  data: unknown;
  errors: null | unknown;
}

export type ListenerHandler = (data: Data, ref?: string) => void;

export type Connection = {
  close: () => void;
  addListener: (id: string | Opcode, listener: ListenerHandler) => () => void;
  sendCast: (opcode: Opcode, data: unknown, ref?: string) => void;
  sendCall: (
    opcode: Opcode,
    data: unknown,
    doneOpcode?: Opcode
  ) => Promise<unknown>;
};

export const connect = ({
  url,
  fetchTimeout,
  waitToReconnect,
}: {
  url?: string;
  fetchTimeout?: number;
  waitToReconnect?: boolean;
}): Promise<Connection> =>
  new Promise((resolve, reject) => {
    const socket = new ReconnectingWebSocket(url || API_BASE_URL, [], {
      connectionTimeout: CONNECTION_TIMEOUT,
      WebSocket,
    });
    const apiSend = (opcode: Opcode, data: unknown, ref?: string) => {
      if (socket.readyState !== socket.OPEN) return;

      const raw = JSON.stringify({
        op: opcode,
        p: data,
        ...({ ref } ?? {}),
      });

      socket.send(raw);
    };

    const listeners = new Map<string | Opcode, ListenerHandler[]>();

    const addHandler = (id: string | Opcode, listener: ListenerHandler) => {
      if (!listeners.has(id)) listeners.set(id, []);
      listeners.get(id)?.push(listener);
      return () => removeHandler(id, listener);
    };

    const removeHandler = (id: string | Opcode, listener: ListenerHandler) => {
      if (!listeners.has(id)) return;
      listeners.get(id)?.splice((listeners.get(id) ?? []).indexOf(listener), 1);
    };

    const executeHandler = (id: string | Opcode, data: Data, ref?: string) => {
      if (!listeners.has(id)) return;
      for (const handler of listeners.get(id) ?? []) {
        handler?.(data, ref);
      }
    };

    socket.addEventListener("close", (error) => {
      console.log(error);
      if (!waitToReconnect) reject(error);
    });

    socket.addEventListener("message", (e) => {
      console.log("INBOUND");
      if (e.data === `"pong"` || e.data === `pong`) {
        return;
      }

      const message = JSON.parse(e.data);
      console.log(message);
      const data = message.d || message.p || message.payload;
      const errors = message.e || message.errors;
      const operator = message.op || message.operator;

      executeHandler(operator, { data, errors }, message.ref);
      if (message.ref)
        executeHandler(message.ref, { data, errors }, message.ref);
    });

    socket.addEventListener("open", () => {
      const id = setInterval(() => {
        if (socket.readyState === socket.CLOSED) {
          clearInterval(id);
        } else {
          socket.send("ping");
        }
      }, HEARTBEAT_INTERVAL);

      const connection: Connection = {
        close: () => socket.close(),
        addListener: addHandler,
        sendCast: apiSend,
        sendCall: (opcode: Opcode, data: unknown, doneOpcode?: Opcode) =>
          new Promise((resolveCall, rejectFetch) => {
            if (socket.readyState !== socket.OPEN) {
              rejectFetch(new Error("websocket not connected"));
              return;
            }

            const ref: string = uuidV4();
            let timeoutId: NodeJS.Timeout | null = null;

            const unsubscribe = connection.addListener(
              doneOpcode ?? opcode + ":reply",
              (data) => {
                console.log("Received data!");
                if (timeoutId) clearTimeout(timeoutId);

                unsubscribe();
                resolveCall(data);
              }
            );

            if (fetchTimeout) {
              timeoutId = setTimeout(() => {
                unsubscribe();
                rejectFetch(new Error("timed out"));
              }, fetchTimeout);
            }

            apiSend(opcode, data, ref);
          }),
      };

      resolve(connection);
    });
  });
