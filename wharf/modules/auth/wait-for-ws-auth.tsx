import React from "react";
import { WebSocketContext } from "../ws/ws-provider";
import { useUserStore } from "@port7/user";
import { useAuthStore } from "./use-auth-store";

export const WaitForWsAndAuth: React.FC = ({ children }) => {
  const { conn } = React.useContext(WebSocketContext);
  const auth = useAuthStore();
  const user = useUserStore();

  const [waiting, setWaiting] = React.useState(true);
  React.useEffect(() => {
    setTimeout(() => setWaiting(false), 500);
  }, []);

  React.useEffect(() => {
    if (auth.isAuthenticated) return;
    if (!conn || !user.user) return;
    // Authentication will be done later when they set their own nickname
    if (!user.user.isPreferredNickname) return;

    conn.addListener("auth:request:reply", () => {
      auth.setIsAuthenticated(true);
    });
    conn.sendCall("auth:request", { nickname: user.user.nickname });
  }, [conn, user]);

  if (!conn || waiting) {
    return (
      <div className="flex text-2xl text-primary-100 m-auto">Loading...</div>
    );
  }

  if (user.user?.isPreferredNickname && !auth.isAuthenticated) {
    return <div className="text-primary-100">Hello</div>;
  }

  return <>{children}</>;
};
