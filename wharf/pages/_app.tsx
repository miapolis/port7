import React from "react";
import "../styles/globals.css";
import type { AppProps } from "next/app";
import { PageComponent } from "../types/page-component";
import { WebSocketProvider } from "../modules/ws/ws-provider";
import { useUserStore } from "../user/use-user-store";
import { doInitialUser } from "../user";
import { MainWsHandlerProvider } from "@port7/hooks/use-main-ws-handler";

function App({ Component, pageProps }: AppProps) {
  const [ready, setReady] = React.useState(false);
  const stored = useUserStore();

  React.useEffect(() => {
    let user = doInitialUser();
    stored.setUser(user.nickname, user.isPreferredNickname);
    setReady(true);
  }, []);

  return (
    <WebSocketProvider
      shouldConnect={!!(Component as PageComponent<unknown>).ws}
    >
      <MainWsHandlerProvider>
        {ready ? <Component {...pageProps} /> : undefined}
      </MainWsHandlerProvider>
    </WebSocketProvider>
  );
}

export default App;
