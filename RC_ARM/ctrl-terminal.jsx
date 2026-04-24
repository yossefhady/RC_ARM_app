// Command log / terminal
function Terminal({ logs, onSend }) {
  const [input, setInput] = useState('');
  const scrollRef = useRef(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [logs]);

  const submit = () => {
    if (!input.trim()) return;
    onSend(input.trim());
    setInput('');
  };

  const colors = {
    out: '#00E5A0',   // sent →
    in:  '#3B9EFF',   // received ←
    info: '#6B7B74',  // system
    err: '#FF4D4D'
  };
  const prefix = { out: '→', in: '←', info: '·', err: '!' };

  return (
    <div style={{
      background: '#0A0C0B',
      border: '1px solid #1F2623',
      borderRadius: 10,
      margin: '0 14px 12px',
      overflow: 'hidden',
      position: 'relative'
    }}>
      {/* header */}
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        padding: '8px 12px',
        borderBottom: '1px solid #1F2623',
        background: 'linear-gradient(180deg, rgba(0,229,160,0.04), transparent)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <div style={{ display: 'flex', gap: 4 }}>
            <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#FF4D4D' }}/>
            <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#6B7B74' }}/>
            <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#00E5A0' }}/>
          </div>
          <div style={{
            fontFamily: 'JetBrains Mono, monospace',
            fontSize: 9, color: '#6B7B74',
            letterSpacing: '0.15em', marginLeft: 4
          }}>esp32 · /dev/ble0</div>
        </div>
        <div style={{
          fontFamily: 'JetBrains Mono', fontSize: 9, color: '#6B7B74',
          letterSpacing: '0.1em'
        }}>{logs.length} EVT</div>
      </div>

      {/* Log body with scanlines */}
      <div ref={scrollRef} style={{
        height: 120,
        overflowY: 'auto',
        padding: '8px 12px',
        fontFamily: 'JetBrains Mono, monospace',
        fontSize: 11, lineHeight: 1.6,
        position: 'relative',
        backgroundImage: 'repeating-linear-gradient(0deg, transparent 0, transparent 2px, rgba(0,229,160,0.015) 2px, rgba(0,229,160,0.015) 3px)'
      }}>
        {logs.map((log, i) => (
          <div key={i} style={{ display: 'flex', gap: 6, color: colors[log.type] }}>
            <span style={{ color: '#6B7B74', opacity: 0.6, fontSize: 9, marginTop: 2 }}>
              {log.ts}
            </span>
            <span style={{ width: 10, textAlign: 'center' }}>{prefix[log.type]}</span>
            <span style={{ flex: 1, wordBreak: 'break-all' }}>{log.msg}</span>
          </div>
        ))}
        {/* Blinking cursor */}
        <div style={{
          display: 'inline-block', width: 7, height: 11,
          background: '#00E5A0', verticalAlign: 'middle',
          animation: 'ctrlBlink 1s steps(2) infinite'
        }}/>
      </div>

      {/* Input row */}
      <div style={{
        display: 'flex', borderTop: '1px solid #1F2623',
        background: '#0D0F0E'
      }}>
        <div style={{
          padding: '0 8px 0 12px', display: 'flex', alignItems: 'center',
          color: '#00E5A0', fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: 600
        }}>$</div>
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter') submit(); }}
          placeholder="send command…"
          style={{
            flex: 1,
            background: 'transparent', border: 'none', outline: 'none',
            padding: '10px 4px',
            fontFamily: 'JetBrains Mono, monospace',
            fontSize: 11,
            color: '#E6EEEA',
            caretColor: '#00E5A0'
          }}/>
        <button onClick={submit} style={{
          padding: '0 14px', background: 'transparent', border: 'none',
          borderLeft: '1px solid #1F2623',
          cursor: 'pointer',
          color: input.trim() ? '#00E5A0' : '#6B7B74'
        }}>
          <IconSend size={16} strokeWidth={1.8}/>
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { Terminal });
