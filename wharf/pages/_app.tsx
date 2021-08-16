import "../styles/globals.css";
import type { AppProps } from "next/app";
import { PageComponent } from "../types/page-component";
import { WebSocketProvider } from "../modules/ws/ws-provider";

function App({ Component, pageProps }: AppProps) {
  // return <Component {...pageProps} />
  return (
    <WebSocketProvider
      shouldConnect={!!(Component as PageComponent<unknown>).ws}
    >
      <Component {...pageProps} />
    </WebSocketProvider>
  );
}

export default App;
