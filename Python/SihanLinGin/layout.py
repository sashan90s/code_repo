# layout.py
import streamlit as st

def app_layout(content_fn):
    st.set_page_config(page_title="My App", layout="wide")
    st.title("🧷SihanLinGin")
    st.markdown("this is the :blue[cool]est data lineage tool :sunglasses: built with DiiS's Sihan and team :rocket:")

    # Content area — call the specific page logic
    content_fn()
    # a subheader
    # then logic
