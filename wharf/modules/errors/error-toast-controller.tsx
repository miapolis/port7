import React from "react";
import { useErrorToastStore } from "./use-error-toast-store";
import { ErrorToast } from "@port7/ui/error-toast";

export const ErrorToastController: React.FC = () => {
  const { toasts, hideToast } = useErrorToastStore();

  return (
    <div
      style={{ zIndex: 1001 }}
      className={`flex w-full fixed top-10 justify-center opacity-90`}
    >
      <div style={{width: "600px"}}>
        <div className={`flex flex-col w-full`}>
          <div className="flex flex-col w-full">
            {toasts.map((t) => (
              <div key={t.id} className={`flex mb-3`}>
                <ErrorToast
                  message={t.message}
                  duration={t.duration}
                  onClose={() => hideToast(t.id)}
                />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
