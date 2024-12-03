import React, { useEffect, useRef } from 'react';
import mermaid from 'mermaid';

mermaid.initialize({
  startOnLoad: true,
  theme: 'default',
  securityLevel: 'loose',
});

const sanitizeDiagram = (diagramText: string) => {
  const directiveRegex = /^%%{init:.*}%%/;

  if (directiveRegex.test(diagramText.trim())) {
    return diagramText;
  }

  const sanitized = diagramText.replace(/[^\w\s\->,:[\]{}()|=;]/g, '');

  return sanitized.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')

    .replace(/\bon\w+\s*=/gi, '')

    .replace(/(?:javascript|data|vbscript):/gi, '')

    .replace(/<!--[\s\S]*?-->/g, '');
};

function MermaidChat ({ diagram, id }: {
  diagram: string;
  id: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [innerHtml, setInnerHtml] = React.useState<string>('');

  useEffect(() => {
    const element = ref.current;

    if (!element) return;

    void (async () => {
      const sanitizedDiagram = sanitizeDiagram(diagram);

      try {
        await mermaid.parse(sanitizedDiagram);
        const { svg } = await mermaid.render(`mermaid-${id}`, diagram);

        setInnerHtml(svg);
      } catch (e) {
        console.error('Invalid diagram');
      }
    })();

  }, [diagram, id]);

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'row',
        placeContent: 'center',
      }}
      contentEditable={false}
      ref={ref}
      dangerouslySetInnerHTML={{ __html: innerHtml }}
    />
  );
}

export default MermaidChat;