import { CustomEditor } from '@/application/slate-yjs/command';
import { CodeNode } from '@/components/editor/editor.type';
import { ThemeModeContext } from '@/components/main/useAppThemeMode';
import { Alert } from '@mui/material';
import React, { useContext, useEffect, useRef } from 'react';
import mermaid from 'mermaid';

const lightTheme = {
  theme: 'base',
  themeVariables: {
    background: '#fff',
    primaryTextColor: '#00bcf0',
    nodeBkg: '#fff',
    nodeTextColor: '#00bcf0',
    nodeBorder: '#00bcf0',
    lineColor: '#00bcf0',
    arrowheadColor: '#00bcf0',
    fontFamily: 'ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, "Apple Color Emoji", Arial, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol"',
    fontSize: '14px',
    mainBkg: '#fff',
    borderColor: '#00bcf0',
    border2: '#00bcf0',
    curve: 'linear',
  },
};

const darkTheme = {
  theme: 'base',
  themeVariables: {
    background: '#1e1e1e',
    primaryTextColor: '#00bcf0',
    nodeBkg: '#1e1e1e',
    nodeTextColor: '#00bcf0',
    nodeBorder: '#00bcf0',
    lineColor: '#00bcf0',
    arrowheadColor: '#00bcf0',
    fontFamily: 'ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, "Apple Color Emoji", Arial, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol"',
    fontSize: '14px',
    mainBkg: '#1e1e1e',
    borderColor: '#00bcf0',
    border2: '#00bcf0',
    curve: 'linear',
  },
};

const sanitizeDiagram = (diagramText: string) => {

  const directiveRegex = /^%%{init:.*}%%/;

  if (directiveRegex.test(diagramText.trim())) {
    return diagramText;
  }

  return diagramText
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/\bon\w+\s*=/gi, '')
    .replace(/(?:javascript|data|vbscript):/gi, '')
    .replace(/<!--[\s\S]*?-->/g, '');
};

function MermaidChat ({ node }: {
  node: CodeNode
}) {
  const id = node.blockId;
  const diagram = CustomEditor.getBlockTextContent(node);
  const ref = useRef<HTMLDivElement>(null);
  const [innerHtml, setInnerHtml] = React.useState<string>('');
  const isDark = useContext(ThemeModeContext)?.isDark;
  const [error, setError] = React.useState<string | null>(null);

  useEffect(() => {
    const element = ref.current;

    if (!element || !diagram) return;

    setError(null);
    void (async () => {
      const sanitizedDiagram = sanitizeDiagram(diagram);
      const theme = isDark ? darkTheme : lightTheme;

      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      mermaid.initialize({
        startOnLoad: true,
        securityLevel: 'loose',
        ...theme,
      });
      try {
        await mermaid.parse(sanitizedDiagram);
        const { svg } = await mermaid.render(`mermaid-${id}`, diagram);

        setInnerHtml(svg);
      } catch (e) {
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        setError(e.message);
      }
    })();

  }, [diagram, id, isDark]);

  if (error) {
    return (
      <div
        contentEditable={false}
      >
        <Alert
          icon={false}
          variant={'outlined'}
          color={'error'}
        >{error}</Alert>
      </div>
    );
  }

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