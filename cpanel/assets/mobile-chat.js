(function(){
  // Add a public Innovation link without replacing the website session/header.
  const addInnovationNav=()=>{
    const nav=document.querySelector('.navlinks');
    if(nav && !nav.querySelector('a[href*="inovasi.php"]')){
      const link=document.createElement('a');
      link.href='/inovasi.php';
      link.textContent='Inovasi';
      link.setAttribute('aria-label','Tiga inovasi Kelurahan Cikoko');
      const login=nav.querySelector('.login-link');
      if(login)nav.insertBefore(link,login);else nav.appendChild(link);
    }
    const quick=document.querySelector('.footer .footer-brand')?.parentElement?.parentElement?.querySelector('div:nth-child(2)');
    if(quick && !quick.querySelector('a[href*="inovasi.php"]')){
      const link=document.createElement('a');link.href='/inovasi.php';link.textContent='Inovasi';quick.appendChild(link);
    }
  };
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',addInnovationNav,{once:true});else addInnovationNav();

  if(document.getElementById('cikoko-chat-float'))return;
  const div=document.createElement('div');div.id='cikoko-chat-float';
  div.innerHTML='<button class="ck-chat-toggle" aria-label="Hubungi Admin">💬 Hubungi Kami</button><section class="ck-chat-box" hidden><header><b>Hubungi Kelurahan Cikoko</b><button class="ck-chat-close" aria-label="Tutup">×</button></header><p>Pesan ditindaklanjuti pada jam kerja: Senin–Kamis 07.30–16.00; Jumat 07.30–16.30 WIB.</p><div class="ck-chat-history"></div><form class="ck-chat-form"><input name="name" placeholder="Nama pengirim" required maxlength="120"><input name="contact" placeholder="Nomor HP / Email (opsional)" maxlength="120"><textarea name="message" required minlength="5" rows="3" placeholder="Tulis pesan untuk admin..."></textarea><input name="website" tabindex="-1" autocomplete="off" style="display:none"><button>Kirim Pesan</button></form><small class="ck-chat-status"></small></section>';
  document.body.appendChild(div);
  const box=div.querySelector('.ck-chat-box'),status=div.querySelector('.ck-chat-status'),history=div.querySelector('.ck-chat-history');let csrf='';
  div.querySelector('.ck-chat-toggle').onclick=()=>{box.hidden=!box.hidden;if(!box.hidden)load();};div.querySelector('.ck-chat-close').onclick=()=>box.hidden=true;
  async function load(){try{const r=await fetch('/mobile-api/web_chat.php',{credentials:'same-origin'});const data=await r.json();csrf=data.csrf;history.replaceChildren();(data.messages||[]).forEach(m=>{const x=document.createElement('div');x.className='ck-message';const b=document.createElement('b');b.textContent=m.sender==='admin'?'Admin: ':'Anda: ';x.append(b,document.createTextNode(m.message));history.appendChild(x);});}catch(_){status.textContent='Tidak dapat mengambil percakapan.';}}
  div.querySelector('form').onsubmit=async e=>{e.preventDefault();const form=e.currentTarget;status.textContent='Mengirim...';const data=Object.fromEntries(new FormData(form).entries());data.csrf=csrf;try{const r=await fetch('/mobile-api/web_chat.php',{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});const v=await r.json();if(!v.ok)throw Error(v.error||'Gagal mengirim');form.elements.message.value='';status.textContent='Pesan diterima dan akan diproses pada jam kerja.';load();}catch(err){status.textContent=err.message;}};
})();
