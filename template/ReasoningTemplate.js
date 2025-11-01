(() => {
      const root  = document.getElementById("ResponseContent");
      let bubble  = document.getElementById("loadingBubble");

      if (!bubble) {
        bubble = document.createElement("div");
        bubble.id = "loadingBubble";
        bubble.className = "chat-bubble assistant loading";
        bubble.textContent = "Developing a response";
        root.appendChild(bubble);
        window.scrollTo(0, document.body.scrollHeight);
      }

      // Hide the bubble after 40 minutes
      setTimeout(() => { bubble.remove(); }, 2400000);
    })();
