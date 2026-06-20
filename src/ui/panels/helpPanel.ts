import type { PanelHandle } from './panelManager';

/**
 * "How to Play" overlay — static content, no callbacks. Construction is
 * byte-for-byte identical to the former inline block in hud.ts so hud.css
 * applies unchanged.
 */
export function createHelpPanel(): PanelHandle {
  const helpPanelEl = document.createElement('div');
  helpPanelEl.id = 'help-panel';
  helpPanelEl.setAttribute('role', 'dialog');
  helpPanelEl.setAttribute('aria-modal', 'true');
  helpPanelEl.setAttribute('aria-label', 'How to play');

  const helpHeaderEl = document.createElement('div');
  helpHeaderEl.id = 'help-panel-header';

  const helpTitleEl = document.createElement('div');
  helpTitleEl.id = 'help-panel-title';
  helpTitleEl.textContent = 'How to Play';

  const helpCloseBtn = document.createElement('button');
  helpCloseBtn.id = 'help-panel-close';
  helpCloseBtn.type = 'button';
  helpCloseBtn.textContent = '✕';
  helpCloseBtn.setAttribute('aria-label', 'Close how to play');

  helpHeaderEl.appendChild(helpTitleEl);
  helpHeaderEl.appendChild(helpCloseBtn);

  const helpBodyEl = document.createElement('div');
  helpBodyEl.id = 'help-panel-body';

  const helpItems: [string, string][] = [
    ['Watch the dog.', 'When it does the trick and a gold ring pulses around BRA, that\'s the moment.'],
    ['Tap BRA on the pulse.', 'Closer to the peak = better; fill the bar to 100% to master the trick.'],
    ['Don\'t tap the wrong thing.', 'A grey, turned-away dog is a distractor — marking it confuses your pup.'],
    ['Chain it.', 'Back-to-back good marks build a combo for bonus rewards.'],
    ['Pick your challenge.', 'Normal / Hard / Expert changes timing. Adopt new breeds and graduate fully-trained dogs for prestige.'],
  ];

  const helpListEl = document.createElement('ul');
  helpListEl.id = 'help-panel-list';

  for (const [bold, rest] of helpItems) {
    const li = document.createElement('li');
    li.className = 'help-panel-item';
    const boldEl = document.createElement('strong');
    boldEl.textContent = bold;
    li.appendChild(boldEl);
    li.appendChild(document.createTextNode(' ' + rest));
    helpListEl.appendChild(li);
  }

  const helpGotItBtn = document.createElement('button');
  helpGotItBtn.id = 'help-panel-got-it';
  helpGotItBtn.type = 'button';
  helpGotItBtn.textContent = 'Got it!';
  helpGotItBtn.setAttribute('aria-label', 'Close how to play');

  helpBodyEl.appendChild(helpListEl);
  helpBodyEl.appendChild(helpGotItBtn);

  helpPanelEl.appendChild(helpHeaderEl);
  helpPanelEl.appendChild(helpBodyEl);
  document.body.appendChild(helpPanelEl);

  function open(): void {
    helpPanelEl.style.display = 'flex';
  }

  function close(): void {
    helpPanelEl.style.display = 'none';
  }

  helpCloseBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    close();
  });

  helpGotItBtn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    close();
  });

  helpPanelEl.style.display = 'none';

  return { el: helpPanelEl, open, close };
}
