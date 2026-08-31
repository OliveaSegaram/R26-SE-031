from fpdf import FPDF
import io

def generate_research_pdf(student_id: str, c1_data: dict, c2_data: dict, c3_data: dict, c4_data: dict) -> bytes:
    pdf = FPDF()
    pdf.add_page()
    
    # Title
    pdf.set_font("Arial", 'B', 16)
    pdf.cell(0, 10, f"Sipsara R26-SE-031 Research Report: {student_id}", ln=True, align='C')
    pdf.ln(10)
    
    # C1
    pdf.set_font("Arial", 'B', 12)
    pdf.cell(0, 10, "C1: Behavioral Telemetry", ln=True)
    pdf.set_font("Arial", '', 10)
    if c1_data:
        pdf.cell(0, 8, f"First Attempt Accuracy: {c1_data.get('first_attempt_accuracy', 'N/A')}", ln=True)
        pdf.cell(0, 8, f"Fatigue Proxy: {c1_data.get('behavioral_fatigue_proxy', 'N/A')}", ln=True)
        pdf.cell(0, 8, f"Errors: {c1_data.get('error_distribution', {})}", ln=True)
    else:
        pdf.cell(0, 8, "No data available.", ln=True)
    pdf.ln(5)
        
    # C2
    pdf.set_font("Arial", 'B', 12)
    pdf.cell(0, 10, "C2: Speech & Acoustic Monitoring", ln=True)
    pdf.set_font("Arial", '', 10)
    if c2_data and c2_data.get('latest'):
        latest = c2_data['latest']
        pdf.cell(0, 8, f"Transcription: {latest.get('transcription', 'N/A')}", ln=True)
        pdf.cell(0, 8, f"WER: {latest.get('wer', 'N/A')}", ln=True)
        pdf.cell(0, 8, f"Acoustic Latency: {latest.get('acoustic_latency_ms', 'N/A')} ms", ln=True)
    else:
        pdf.cell(0, 8, "No data available.", ln=True)
    pdf.ln(5)

    # C3
    pdf.set_font("Arial", 'B', 12)
    pdf.cell(0, 10, "C3: Diagnostic Fusion & XAI", ln=True)
    pdf.set_font("Arial", '', 10)
    if c3_data:
        pdf.cell(0, 8, f"Primary Pattern: {c3_data.get('primary_pattern', 'N/A')}", ln=True)
        pdf.cell(0, 8, f"Confidence: {c3_data.get('confidence', 'N/A')}", ln=True)
        if 'llm_summary' in c3_data and c3_data['llm_summary']:
            # Replace unsupported characters for standard fonts or just use encode string
            summary_text = str(c3_data['llm_summary']).encode('latin-1', 'replace').decode('latin-1')
            pdf.multi_cell(0, 8, f"Summary: {summary_text}")
    else:
        pdf.cell(0, 8, "No data available.", ln=True)
    pdf.ln(5)

    # C4
    pdf.set_font("Arial", 'B', 12)
    pdf.cell(0, 10, "C4: Adaptive Tutoring Decisions", ln=True)
    pdf.set_font("Arial", '', 10)
    if c4_data:
        pdf.cell(0, 8, f"Estimated Theta: {c4_data.get('theta', 'N/A')}", ln=True)
        if c4_data.get('history') and len(c4_data['history']) > 0:
            last = c4_data['history'][-1]
            decision_text = str(last.get('decision', 'N/A')).encode('latin-1', 'replace').decode('latin-1')
            pdf.multi_cell(0, 8, f"Last Decision: {decision_text}")
    else:
        pdf.cell(0, 8, "No data available.", ln=True)

    # Return bytes
    out = pdf.output(dest='S')
    if isinstance(out, (bytes, bytearray)):
        return bytes(out)
    return out.encode('latin1')
